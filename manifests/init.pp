# Class: serverdensity
#
# This class installs and configures the Server Density monitoring agent: http://www.serverdensity.com/
#
# Notes:
#  This class is Ubuntu/Debian specific for now.
#  By Sean Porter, Gastown Labs Inc.
#
# Actions:
#  - Adds to the apt repository list
#  - Installs and configures the Server Density monitoring agent, sd-agent
#
# Sample Usage (Monitoring MongoDB):
#  include serverdensity
#
#  serverdensity::config { "server-density-subdomain":
#    agent_key => "b82e833n4o9h189a352k8ds67725g3jy",
#    options => ["mongodb_server: localhost"],
#  }
#
class serverdensity {
	define config ( $agent_key, $options=[""] ) {
		exec { "server-density-apt-key":
			path => "/bin:/usr/bin",
			command => "wget http://www.serverdensity.com/downloads/boxedice-public.key && rpm --import boxedice-public.key",
			unless => "yum repolist | grep -i serverdensity",
		}

		yumrepo { "serverdensity":
			baseurl => "http://www.serverdensity.com/downloads/linux/redhat/",
			descr => "The serverdensity repository",
			enabled => "1",
			gpgcheck => "1",
			require => Exec["server-density-apt-key"],
		}

		package { "python-devel":
			ensure => installed,
		}

    # if mysql options are set, include the python package
		if 'mysql_server' in $options {
			package { "MySQL-python":
				ensure => installed,
				require => Package['python-devel'],
			}
		}

		package { "sd-agent":
			ensure => installed,
			require => Yumrepo["serverdensity"],
		}

		file { "/etc/sd-agent/config.cfg":
			content => template("serverdensity/config.cfg.erb"),
			mode => "0644",
			require => Package["sd-agent"],
		}

		service { "sd-agent":
			ensure => running,
			enable => true,
			subscribe => Package["sd-agent"],
			require => File["/etc/sd-agent/config.cfg"],
		}
	}
}
