require 'json'
require 'deploy/application/paths'

module Deploy
  class Application
    attr_reader :name, :root, :paths

    def exists?
      File.exists?(root)
    end

    def config(force_update=false)
      file = paths.repo.join('deploy.json')
      @config = nil if force_update
      @config ||= Hashie::Mash.new(File.exists?(file) ? JSON.load(File.open(file)) : {})
    end

    def recipes
      config.recipes || []
    end

    def events
      config.events || {}
    end

    def listener
      @listener ||= begin
        listener = Listeners.new

        events.keys.each do |key|
          if key.match(/^(on|before|after)_(\w+)/)
            commands = events[key]
            commands = [commands] if commands.is_a?(String)
            commands.each do |command|
              listener.send($1, $2, &->{ Shell::Command.new(command, { chdir: paths.current.to_s }) })
            end
          end
        end

        listener
      end
    end

  private

    def initialize(app_name)
      world  = Deploy.world

      @name  = app_name.to_sym
      @root  = world.paths.app(app_name)
      @paths = Paths.new(root)
    end

  end
end
