#!/usr/bin/ruby

# Nagios check for HAProxy status

STDOUT.sync = true

require 'optparse'
require 'yaml'
require 'pp'
require 'csv'
require 'net/http'
require 'uri'
require 'socket'


STATSCOMMAND = "show stat\n"

class CheckHAProxyError < StandardError
end

class CheckHAProxyStatus

  # given an upCount and threshold will return an array of check status
  # and error message if any

  def self.check_haproxy_status(stat)
    msg = []
    nag_status = 2
    begin
    stat.each do |name , status|
      if status == "UP"
        msg << "OK : " + name + " is " + status 
        nag_status = 0
      elsif status == "DOWN"
        msg << "CRITICAL: " + name + " is " + status
        nag_status = 2
      else
        msg << nil
        nag_status = 2
      end
    end
    rescue Exception => e
    # msg = "HAProxy Status Failed #{e.message}"
      msg = "HAProxy Status Failed"
      nag_status = 2
    end
    [nag_status, msg]
  end

  def self.parse(args)
    options = {}
    opts = OptionParser.new do |opts|
      opts.banner = "Usage #{__FILE__} [options]"
      opts.separator ""
      options[:socket] = "/var/run/haproxy/haproxy.sock"
      opts.on("-s","--socket SOCKET","Please provide the socket location"\
              "By Default location is " + options[:socket]) do |s|
        options[:socket] = s
      end

      options[:sname] = "cbp_server"
      opts.on("-n","--name NAME", "Please specify the pattern match string for the server"\
              "By default string set to " + options[:sname]) do |n|
        options[:sname] = n
       end

      opts.on_tail("-h","--help","Show this message") do
        puts opts
        exit
      end
    end
    begin
      opts.parse!(args)
    rescue Exception => e
      puts "Error " + e, "#{__FILE__} -h for options"
      exit
    end
    options
  end

  def self.stats_parse(data,pattern)
    summary = {}
    data.split("\n").each do |l|
      stat = l.split(",")
      if stat[1] =~ /^#{pattern}\d/
        summary[stat[1]] = stat[17]
      end
  end
   summary
 end

  def self.run(args)
    opts = parse(args)
    nag_msg = []
    status = 0
    begin
      socket = UNIXSocket.new(opts[:socket])
      socket.write(STATSCOMMAND)
      socket_data = socket.read
      socket.close
      if socket_data
        @stats = stats_parse(socket_data,opts[:sname])
       else
          puts "No data received from the socket"
      end
    rescue Exception => e
      #puts e
      puts e.message
    ensure
      socket.close if !socket.nil? && !socket.closed?
    end
      st,msg = check_haproxy_status(@stats)
      status = 2 if st != 0
      nag_msg << msg
      puts nag_msg.join("\n")
      exit status
    end
  end
CheckHAProxyStatus.run(ARGV)
