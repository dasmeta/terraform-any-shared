source = File.read(File.expand_path("../locals.tf", __dir__))
script = source[/bootstrap_command = <<-EOT\n(.*?)\nEOT/m, 1]

abort "bootstrap command heredoc not found" unless script
abort "existing-user path still overwrites the full payload" if script.include?("existing.update(payload)")
abort "existing-user path still overwrites filters" if script.include?("filters.update(payload[\"filters\"])")
abort "existing-user path must update non-credential fields explicitly" unless script.include?("existing.update({")
abort "existing-user path must preserve the password" unless script.include?("existing.pop(\"password\", None)")

puts "bootstrap user preservation ok"
