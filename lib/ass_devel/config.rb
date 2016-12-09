module AssDevel
  class Config
    require 'logger'
    attr_writer :logger
    def logger
      @logger ||= Logger.new STDERR
    end
  end

  def self.configure(&block)
    yield config if block_given?
  end

  def self.config
    @config ||= Config.new
  end
end
