require "test/unit"
require 'rdoc/generator/paddle'
require 'tempfile'
require 'fileutils'

class TestPaddle < Test::Unit::TestCase
  def setup
    @dirname = File.join(Dir.tmpdir, Time.now.to_i.to_s)
    p @dirname
    rdoc = RDoc::RDoc.new
    rdoc.document ['--op', @dirname, '-q', '-f', 'paddle']
  end
end
