source = File.read(File.expand_path("../sftp_service.tf", __dir__))
variables = File.read(File.expand_path("../variables.tf", __dir__))

abort "sftp_service must declare the AWS NLB load balancer class" unless variables.match?(/load_balancer_class\s*=\s*optional\(string, "service\.k8s\.aws\/nlb"\)/)
abort "LoadBalancer services must persist the AWS NLB class" unless source.match?(/load_balancer_class\s*=\s*var\.sftp_service\.type == "LoadBalancer" \? var\.sftp_service\.load_balancer_class : null/)
abort "source ranges must use an explicit empty list when unset" unless source.match?(/load_balancer_source_ranges\s*=\s*coalesce\(var\.sftp_service\.load_balancer_source_ranges, \[\]\)/)

puts "sftp service stability ok"
