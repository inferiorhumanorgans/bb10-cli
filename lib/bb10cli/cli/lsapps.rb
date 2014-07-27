module Bb10Cli
  module Cli
    class App
      desc 'lsapps [PACKAGE]', 'Lists applications installed on a BB10 device'
      def lsapps(package=nil)
        run_command do |bb|
          apps = bb.do_command(:LIST)

          skip = true
          apps = apps.split("\n").collect do |line|
            if line == '@applications'
              skip = false
              next
            end
            next if skip
            line
          end.compact

          apps.collect! do |app|
            app = app.split(',', 7)
            (name, id) = app[0].split('::', 2)
            h = {package_name: name, package_id: id, version: app[1], unknown: app[2], unknown2: app[3], size: app[4]}

            app[5..6].each do |vararg|
              next unless vararg
              (key,value) = vararg.split('::', 2)
              if key == 'dat'
                h[key.to_sym] = JSON.parse(value)
              elsif key
                h[key.to_sym] = value
              end
            end

            h if package.nil? or name.index(package)
          end.compact!

          case options[:format]
          when 'json'
            STDOUT.write JSON.generate({applications: apps}, JSON_OPTS) + "\n"
          when 'short'
            apps.each do |app|
              puts [app[:package_name], app[:package_id], app[:version]].join(',')
            end
          when 'csv'
          end

          nil
        end
      end
    end
  end
end
