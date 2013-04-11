$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'
require 'open-uri'

def links(n=rand(1072))
  list = []
  n = "%04d" % n
  open("http://abcnotation.com/browseTunes?n=#{n}") do |f|
    f.each_line do |line|
      match = line.match /href=\"(.tunePage[^\"]+)\"/
        list << match[1] if match
    end
  end
  list
end

def abc(link)
  abc = ""
  reading = false
  open("http://abcnotation.com#{link}") do |f|
    f.each_line do |line| 
      reading = true if line.match /<textarea/
      reading = false if line.match /<\/textarea/
      abc += line if reading
    end
  end
  abc
end

def random_abc()
  links = links()
  links[rand(links.count)]
end

describe "corpus source" do
  it "yeilds abc files" do
    random_abc().length.should > 0
  end
end

describe "parser" do
  it "can parse published abc files" do
    parse(random_abc())
  end
end
