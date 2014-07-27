module Bb10Cli
  class Bb10Protocol
    DEFAULT_OPTIONS = {}
    USER_AGENT      = 'QNXWebClient/1.0'

    COMMANDS = {
      TEST:                 'test',
      INSTALL:              'Install',
      UNINSTALL:            'Uninstall',
      TERMINATE:            'Terminate',
      LAUNCH:               'Launch',
      INSTALL_AND_LAUNCH:   'Install and Launch',
      IS_RUNNING:           'Is Running',
      LIST:                 'List',
      INSTALL_DEBUG_TOKEN:  'Install Debug Token',
      DEVICE_INFO:          'List Device Info',
      GET_FILE:             'Get File',
      PUT_FILE:             'Put File',
      VERIFY:               'Verify'
    }

    class HTTPClient
      include HTTParty_with_cookies
    end

    attr_reader :options

    def initialize(_options={})
      @options = DEFAULT_OPTIONS.merge(_options)
      @verbose = @options[:cli][:verbose]
      @ip_address = @options[:ip_address]
    end

    def cookies
      @http_client.cookies
    end

    def do_query(path, query)
      @http_client ||= HTTPClient.new

      STDERR.puts ">>> GET: #{path} -> #{query.inspect}" if @verbose
      @http_client.get(File.join("https://#{@ip_address}/", path), query: query, headers: {'User-Agent' => USER_AGENT}, verify: false)
    end

    def do_post(path, query)
      multipart = Net::HTTP::Post::Multipart.new 'url.path', query
      body = multipart.body_stream.read.to_s

      @http_client ||= HTTPClient.new

      STDERR.puts ">>> POST: #{path} -> #{query.inspect}" if @verbose
      @http_client.post(File.join("https://#{@ip_address}/", path),
        body: body,
        headers: {
          'User-Agent' => USER_AGENT,
          'Content-Type' => 'multipart/form-data; boundary=-----------RubyMultipartPost'
        },
        verify: false
      )
    end

    def do_login(_password=nil)
      login_base_path = '/cgi-bin/login.cgi'
      password = _password || @options[:password]

      query_context = {request_version: 1}

      STDERR.puts '>>> Initial login request' if @verbose
      while (response = do_query(login_base_path, query_context)) do

        STDERR.puts "<<< Response: #{response.body.to_s}" if @verbose

        bb_response = response['RimTabletResponse']

        case bb_response.values.first['Status']
        when '*** Denied'
          STDERR.puts 'Login Denied' if @verbose
          return response
        when 'Error'
          STDERR.puts '*** Error' if @verbose
          return response
        when 'PasswdChallenge'
          STDERR.puts '*** Challenge' if @verbose
          challenge = bb_response['AuthChallenge']['Challenge']
          algorithm = bb_response['AuthChallenge']['Algorithm'].to_i
          salt      = bb_response['AuthChallenge']['Salt']
          icount    = bb_response['AuthChallenge']['ICount'].to_i

          saltbytes = [salt].pack('H*').bytes.to_a

          case algorithm.to_i
          when 2
            STDERR.puts '*** V2 Login' if @verbose

            hash1 = hash_password(saltbytes, icount, password.bytes.to_a)

            hash2 = []
            hash2 += challenge.bytes.to_a
            hash2 += hash1
            hash2 = hash_password(saltbytes, icount, hash2)

            hex_encoded = to_hex(hash2)

            query_context[:challenge_data] = hex_encoded
          end

        when 'Success'
          STDERR.puts '*** Success' if @verbose

          if cookies['dtmauth'].nil?
            raise raise Exceptions::InvalidAuthCookieError
          end

          STDERR.puts if @verbose
          return response
        else
          STDERR.puts '*** Unknown problem logging in' if @verbose
          return response
        end
        STDERR.puts if @verbose
      end

      response
    end

    def do_command(cmd, _options={})
      options = ({path: '/cgi-bin/appInstaller.cgi'}).merge(_options)
      command_base_path = options.delete(:path)

      args = {'dev_mode' => 'on'}
      args['command'] = COMMANDS[cmd] || cmd if cmd

      do_post(command_base_path, args.merge(options))
    end

    protected

    def to_hex(buf)
      buf.pack('c*').unpack('H*').join.upcase
    end

    def hash_password(salt, iterations, password)
      data = password.dup

      iterations.times do |it|
        hash1 = [it].pack('L').bytes.to_a
        hash1 += salt
        hash1 += data

        d = Digest::SHA512.new
        d << hash1.pack('c*')
        data = d.digest.bytes.to_a
      end
      data
    end
  end
end
