Haproxy Monitoring
==================

For using the haproxy_stats plugin for collectd

Add the below lines to the types.db

hproxy_status          status:GAUGE:0:U
haproxy_traffic         stot:COUNTER:0:U, eresp:COUNTER:0:U, chkfail:COUNTER:0:U
haproxy_sessions        qcur:GAUGE:0:U, scur:GAUGE:0:U

Add these lines in the collectd conf for the execution of the plugin

LoadPlugin exec

<Plugin exec>
 #userid plugin executable plugin args

  Exec "haproxy" "/usr/lib/collectd/plugins/haproxy" "-s" "/var/run/hproxy/haproxy.sock"  "-e" "listen_directive_from_haproxy_config" "-n" "BACKEND" -w "10"

</Plugin>
