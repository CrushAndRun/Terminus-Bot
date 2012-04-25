#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Bot
  Script_Info = Struct.new(:name, :description)

  class ScriptManager

    attr_reader :script_info

    # TODO: Rework this whole file. Stop this stupid string juggling.

    def initialize
      @scripts, @script_info = {}, []

      unless Dir.exists? "scripts"
        raise "Scripts directory does not exist."
      end
    end

    # Load all the scripts in the scripts directory.
    def load_scripts
      $log.info("ScriptManager.initilize") { "Loading scripts." }

      noload = Config[:core][:noload]

      noload = noload.split unless noload == nil

      Dir.glob("scripts/*.rb").each do |file|

        unless noload == nil
          # I realize we are pulling the name out twice. Deal with it.
          next if noload.include? file.match("scripts/(.+).rb")[1]
        end

        $log.debug("ScriptManager.initilize") { "Loading #{file}" }
        load_file(file)

      end
    end

    # Run the die functions on all scripts.
    def die
      @scripts.each_value {|s| s.die if s.respond_to? "die"}
    end

    # Load the given script by file name. The relative path should be included.
    # Scripts are expected to be in the scripts dir.
    def load_file(filename)
      unless File.exists? filename
        raise "File #{filename} does not exist."
      end

      name = filename.match("scripts/(.+).rb")[1]

      $log.debug("ScriptManager.load_file") { "Script file name: #{filename}" }

      script = "class Script_#{name} < Script \n #{IO.read(filename)} \n end \n Script_#{name}.new"

      if @scripts.has_key? name
        raise "Attempted to load script that is already loaded."
      end

      begin
        @scripts[name] = eval(script, nil, filename, 0)
      rescue Exception => e
        $log.error("ScriptManager.load_file") { "Problem loading script #{name}. Clearing data and aborting..." }

        if @scripts.has_key? name

          @scripts[name].unregister_script
          @scripts[name].unregister_commands
          @scripts[name].unregister_events

          @scripts.delete(name)

        end

        raise "Problem loading script #{name}: #{e}: #{e.backtrace}"
      end
    end

    # Unload and then load a script. The name given is the script's short name
    # (script/short_name.rb).
    def reload(name)
      raise "Cannot reload: No such script #{name}" unless @scripts.has_key? name

      filename = "scripts/#{name}.rb"

      raise "Script file for #{name} does not exist (#{filename})." unless File.exists? filename

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete(name)

      load_file(filename)
    end

    # Unload a script. The name given is the script's short name
    # (scripts/short_name.rb).
    def unload(name)
      raise "Cannot unload: No such script #{name}" unless @scripts.has_key? name

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete(name)
    end

    def register_script(*args)
      $log.debug("ScriptManager.register_script") { "Registering script: #{args.to_s}" }

      script = Script_Info.new(*args)

      @script_info << script
      Bot::Flags.add_script(script.name)

      @script_info.sort_by! {|s| s.name}
    end

    def unregister_script(name)
      $log.debug("ScriptManager.register_script") { "Unregistering script: #{name}" }
      @script_info.delete_if {|s| s.name == name}
    end
  end

  class Script

    # Cheat mode for passing functions to Bot.
    # There's probably a better way to do this.
    #def method_missing(name, *args, &block)
    #  if Bot.respond_to? name
    #    Bot.send(name, *args, &block)
    #  else
    #    $log.error("Script.method_missing") { "Attempted to call nonexistent method #{name}" }
    #    raise NoMethodError.new("#{my_name} attempted to call a nonexistent method #{name}", name, args)
    #  end
    #end

    # Pass along some register commands with self or our class name attached
    # as needed. This just makes code in the scripts a little shorter.

    def register_event(*args)
      Bot::Events.create(self, *args)
    end

    def register_command(*args)
      Bot::Commands.create(self, *args)
    end

    def register_script(*args)
      Bot::Scripts.register_script(my_short_name, *args)
    end


    # Shortcuts for unregister stuff. Makes teardown easier in die methods.

    def unregister_commands
      Bot::Commands.delete_for(self)
    end

    def unregister_events
      Bot::Events.delete_for(self)
    end

    def unregister_script
      Bot::Scripts.unregister_script(my_short_name)
    end


    # Dunno if these should be functions or variables. Feel free to change.


    def my_name 
      self.class.name.split("::").last
    end

    def my_short_name 
      self.class.name.split("_").last
    end


    # Get config data for this script, if it exists. The section name
    # in the config is the script's short name. Configuration in this
    # version of Terminus-Bot is read-only, unlike the YAML-based config
    # in the previous version. If you want to store data, you want to use
    # the database. See functions below for that!
    def get_config(key, default = nil)
      name_key = my_short_name.to_sym

      if Bot::Config.has_key? name_key
        if Bot::Config[name_key].has_key? key
          return Bot::Config[name_key][key]
        end
      end

      default
    end

    # Check if the database has a Hash table for this plugin. If not,
    # create an empty one.
    def init_data
      Bot::DB[my_name] ||= Hash.new
    end

    # Get the value stored for the given key in the database for this
    # script. The optional default value is what is returned if not value
    # exists for the given key.
    def get_data(key, default = nil)
      init_data

      if Bot::DB[my_name].has_key? key
        return Bot::DB[my_name][key]
      end

      default
    end

    # Get all of the data for this script.
    def get_all_data
      init_data

      Bot::DB[my_name]
    end

    # Store the given value in the database if one isn't already set.
    def default_data(key, value)
      init_data

      Bot::DB[my_name][key] ||= value
    end

    # Store a value in the database under the given key.
    def store_data(key, value)
      init_data

      Bot::DB[my_name][key] = value
    end

    # Delete data under the given key, if it exists.
    def delete_data(key)
      init_data

      if Bot::DB[my_name].has_key? key
        Bot::DB[my_name].delete(key)
      end
    end

    def to_str
      my_short_name
    end
  end

  Scripts = ScriptManager.new
  Scripts.load_scripts

end
