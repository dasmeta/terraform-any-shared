"""One bounded Opsgenie daily summary with the same inventory sample as Slack."""
import copy
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'notifier'))
from notifier.engine import Engine
from notifier.source import Source
from notifier.delivery import Sender as DeliverySender
from test_notifications import FakeAPI,MemoryStore,Sender,NOW
from test_notifications_delivery import FakeHTTP,response,SECRETS

class CompactOpsgenieSummaryTests(unittest.TestCase):
    def setUp(self):
        self.policy=dict(namespace='example',api_url='https://dojo.example.com',time_zone='UTC',engagement_ids=[1],all_engagements=False)
        self.engine=Engine(None,None,None,self.policy,now=NOW)
        self.engine.generation='a'*32
    def records(self,count=220):
        return [dict(id=i,title=f'UNIQUE-{i}: CVE-2026-12345 example-package 1.2.3',date='2026-11-01' if i>=210 else '2026-11-05',
                     engagement_name='Example',url=f'https://scanner.example.com/finding/{i}') for i in range(1,count+1)]
    def test_220_findings_make_one_opsgenie_summary_with_slack_counts_and_oldest_five(self):
        rows=self.records();before=copy.deepcopy(rows)
        _,events=self.engine.daily_events(1,rows,[])
        ops=[e for e in events if e['channel']=='opsgenie'];slack=[e for e in events if e['channel']=='slack']
        self.assertEqual(len(ops),1)
        self.assertEqual(ops[0]['payload']['summary'],slack[0]['payload']['summary'])
        self.assertEqual([r['id'] for r in ops[0]['payload']['summary']['findings']],[210,211,212,213,214])
        text=ops[0]['payload']['text']
        for value in ('Open Critical: 220','New (24h): 0','Fixed (24h): 0','Showing 5 of 220','View All Findings','https://dojo.example.com/engagement/1'):
            self.assertIn(value,text)
        self.assertEqual(text.count('/finding/'),5)
        self.assertNotIn('scanner.example.com',text)
        self.assertNotIn('Part:',text)
        self.assertNotIn('(1/',ops[0]['payload']['title'])
        self.assertTrue(ops[0]['stream'].endswith(':digest:1:2026-11-12:1'))
        self.assertEqual(rows,before)
    def test_long_titles_reduce_sample_without_changing_counts_or_splitting_alert(self):
        rows=self.records(6)
        rows[0]['title']='😀\\"'*9000
        _,events=self.engine.daily_events(1,rows,[])
        ops=[e for e in events if e['channel']=='opsgenie']
        self.assertEqual(len(ops),1)
        text=ops[0]['payload']['text']
        self.assertLessEqual(len(text),15000)
        self.assertIn('Showing 0 of 6',text)
        self.assertIn('https://dojo.example.com/engagement/1',text)
        self.assertNotIn('UNIQUE-2:',text) # Keep the oldest prefix rather than skip an oversized first item.
        http=FakeHTTP(response(202,{'requestId':'receipt-1'}))
        DeliverySender(SECRETS,http=http).send(ops[0])
        self.assertLessEqual(len(http.calls[0][2]['body']),65536)
    def test_compact_summary_keeps_p5_tags_and_client_prefix(self):
        _,events=self.engine.daily_events(1,self.records(),[])
        event=next(e for e in events if e['channel']=='opsgenie')
        self.assertNotIn('(1/',event['payload']['title'])
        http=FakeHTTP(response(202,{'requestId':'receipt-1'}))
        DeliverySender(SECRETS,http=http,title_prefix='Example Security:').send(event)
        body=json.loads(http.calls[0][2]['body'])
        self.assertEqual(body['priority'],'P5')
        self.assertEqual(body['tags'],['defectdojo','defectdojo-summary'])
        self.assertTrue(body['message'].startswith('Example Security: Critical Findings Summary'))
        self.assertEqual(body['alias'],event['payload']['alias'])
    def test_existing_frozen_multipart_queue_is_not_rewritten_or_appended(self):
        api,store,sender=FakeAPI(),MemoryStore(),Sender()
        engine=Engine(Source(api,self.policy,now=NOW),store,sender,self.policy,now=NOW,channels=('opsgenie',))
        store.manifests.add((str(NOW.date()),1))
        old=[]
        for index in (1,2):
            old.extend(engine.events(f'legacy-part-{index}','digest',f'legacy-part-{index}',
                       dict(title=f'Old summary ({index}/2)',text=f'Old full-list part {index}',engagement_id=1)))
        store.enqueue(old)
        frozen=[copy.deepcopy(e['payload']) for e in store.events]
        engine.run('digest')
        self.assertEqual(len(store.events),2)
        self.assertEqual([e['payload'] for e in store.events],frozen)
        self.assertEqual([e['payload'] for e in sender.calls],frozen)
