# frozen_string_literal: true

module VisualReportHelper
  VISUAL_REPORT_TEMPLATE = <<-HTML
    <!DOCTYPE html>
    <html >
    <head>
    <title>Morandi report</title>
    <meta charset="utf-8">
    <style>
    .img-block { display: inline-block; margin-right: 20px; }
    th, td { text-align: left; vertical-align: top; }
    </style>
    </head>
    <body>
      <table width="100%" border="1">
      <thead>
        <tr>
          <th width="20%">Description</th>
          <th width="80%">Image</th>
        </tr>
      </thead>
      <tbody>
          <!-- insert results -->
      </tbody>
      </table>
      <script>
        window.onload = function () {
          if (sessionStorage.scrollToBottom == "yes") {
            window.scrollTo({top: document.body.offsetHeight - window.innerHeight + 50, behavior: 'smooth' })
          }
          setInterval(() => fetch(location.href).then(response => response.text()).then(body => {
            if ([...body.matchAll(/[<]img /g)].length !== document.getElementsByTagName('img').length) {
              sessionStorage.scrollToBottom = (window.innerHeight + window.scrollY) >= document.body.offsetHeight ? "yes" : "no";
              window.location.reload();
            }
          }), 500);
        }
      </script>
    </body>
    </html>
  HTML

  class << self
    attr_accessor :group
  end

  module_function

  def visual_report_path
    'spec/reports/visual_report.html'
  end

  def create_visual_report
    File.open(visual_report_path, 'w') do |fp|
      fp << VISUAL_REPORT_TEMPLATE
    end
  end

  def add_to_visual_report(example, files)
    lines = IO.readlines(visual_report_path)
    File.open(visual_report_path, 'w') do |fp|
      lines.each do |line|
        if line =~ /insert results/
          group = description_of(example)
          fp.puts %(<tr><th colspan=2>#{group}</th><tr>) unless VisualReportHelper.group == group
          fp.puts %(<tr><td>#{example.description})
          fp.puts %(<pre>#{CGI.escapeHTML(JSON.pretty_generate(example.example_group_instance.options))}</pre>)
          fp.puts %(</td><td>)
          files.each.with_index do |filename, index|
            next if File.basename(filename) == 'sample.jpg.icc.jpg'

            base = name_for(filename, example, index)
            FileUtils.cp(filename, "spec/reports/#{base}")
            fp << %(<div class="img-block"><img src="#{base}" style="max-width: 300px; height: auto;"><br>)
            type, width, height = GdkPixbuf::Pixbuf.get_file_info(filename)
            fp << "w: #{width}, h: #{height}, t: #{type&.name},<br>" \
              "f: #{File.basename(filename)}, s: #{File.size(filename)}</div>"
          end
          fp.puts %(</td></tr>)
          VisualReportHelper.group = group
        end
        fp.puts line
      end
    end
  end

  def description_of(example)
    example.example_group.parent_groups.map(&:description).reverse.join(' | ')
  end

  def name_for(filename, example, index)
    name = "#{description_of(example)} #{example.description}"
    name.downcase.gsub(/[^0-9a-z]/, '_') + "_#{index}#{File.extname(filename)}"
  end
end
