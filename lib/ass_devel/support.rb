module AssDevel
  module Support
    module TmpPath
      require 'tempfile'
      def tmp_path(ext)
        tf = Tempfile.new(ext)
        tf.unlink
        tf.to_path
      end
    end

    module Logger
      def logger
        AssDevel.config.logger
      end
    end
  end
end
