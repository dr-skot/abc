require 'i18n'

module ABC
  # TODO is there a better way to specify the dir?
  # TODO do we have to use the global I18n or can we have a particular instance for ABC?
  I18n.load_path += Dir[File.expand_path(File.dirname(__FILE__)) + '/i18n/*.yml']
end
