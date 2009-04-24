$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutemaweb/gems'

module Rutema
  module UI
    # Formats the test scenario data into a vertical folding structure
    class VerticalTableFormatter < Ruport::Formatter::HTML 

      renders :vhtml, :for => Ruport::Controller::Table

      def build_table_body
        data.each do |row|
          build_row(row)
        end
      end

      def build_table_header
      end

      def build_table_footer
      end

      def build_row(data = self.data)
        output << "<table class=\"vtable\"><colgroup><col width=\"100\"><col></colgroup>\n"
        output << "<tr><td>#{data['status']}</td><td colspan=\"2\"><h3>#{data['number']} - #{data['name']}</h3></td></tr>"
        output << "<tr><td>duration:</td><td>#{data['duration']}</td></tr>\n"
        %w(output error).each { |k| output << "<tr><td colspan=\"2\"><div onclick=\"toggleContentFolding(this)\">#{k} - click me<pre style=\"display:none;\">#{data.get(k)}</pre></div></td></tr>\n" if data.get(k).size > 0 }
        output << "</table>\n"
      end
    end
  end
end