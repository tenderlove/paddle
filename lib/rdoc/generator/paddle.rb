require 'rdoc/generator'
require 'rdoc/rdoc'
require 'paddle'
require 'erb'
require 'md5'
require 'fileutils'

class RDoc::Generator::Paddle
  RDoc::RDoc.add_generator self

  TEMPLATE_DIR = File.expand_path(
    File.join(File.dirname(__FILE__), '..', '..', 'templates'))
  IMAGE_DIR = File.expand_path(
    File.join(File.dirname(__FILE__), '..', '..', 'images'))

  class << self
    alias :for :new
  end

  def initialize options
    @options   = options
    @class_dir = nil
    @file_dir  = nil
    @odir      = Pathname.new(options.op_dir).expand_path(Pathname.pwd)
    @fh        = nil
    @files     = nil
  end

  def generate top_levels
    @files   = top_levels
    @classes = RDoc::TopLevel.all_classes_and_modules.reject { |x|
      x.name =~ /[<>]/
    }

    FileUtils.mkdir_p(File.join(@odir, class_dir))

    emit_mimetype
    emit_meta_inf
    emit_cover
    emit_title
    emit_opf
    emit_toc
    emit_classfiles
    copy_images
  end

  def class_dir
    '/doc'
  end

  def title
    @options.title
  end

  def identifier
    MD5.hexdigest title
  end

  private
  def h string
    string.strip.gsub(/<pre>\s*<\/pre>/, '').gsub(/& /, '&amp; ').gsub(/<</, '&lt;&lt;')
  end

  def copy_images
    imgs = File.join @odir, 'images'
    FileUtils.mkdir_p imgs

    FileUtils.cp File.join(IMAGE_DIR, 'ruby.png'), imgs
  end

  def emit_meta_inf
    meta_inf = File.join @odir, 'META-INF'
    FileUtils.mkdir_p meta_inf

    FileUtils.cp File.join(TEMPLATE_DIR, 'container.xml'), meta_inf
  end

  def emit_mimetype
    File.open(File.join(@odir, 'mimetype'), 'wb') do |f|
      f.write 'application/epub+zip'
    end
  end

  def emit_cover
    template = ERB.new File.read(File.join(TEMPLATE_DIR, 'cover.html.erb')),
      nil, '<>'

    File.open(File.join(@odir, class_dir, 'cover.html'), 'wb') do |f|
      f.write template.result binding
    end
  end

  def emit_title
    template = ERB.new File.read(File.join(TEMPLATE_DIR, 'title.html.erb')),
      nil, '<>'

    File.open(File.join(@odir, class_dir, 'title.html'), 'wb') do |f|
      f.write template.result binding
    end
  end

  def emit_classfiles
    @classes.each do |klass|
      klass_methods    = []
      instance_methods = []

      klass.method_list.each do |method|
        next if 'private' == method.visibility.to_s
        if method.type == 'class'
          klass_methods << method
        else
          instance_methods << method
        end
      end

      template = ERB.new File.read(File.join(TEMPLATE_DIR, 'classfile.html.erb')),
        nil, '<>'

      FileUtils.mkdir_p(File.dirname(File.join(@odir, klass.path)))

      File.open(File.join(@odir, klass.path), 'wb') do |f|
        f.write template.result binding
      end
    end
  end

  def emit_opf
    template = ERB.new File.read(File.join(TEMPLATE_DIR, 'content.opf.erb')),
      nil, '<>'

    File.open(File.join(@odir, 'content.opf'), 'wb') do |f|
      f.write template.result binding
    end
  end

  def emit_toc
    template = ERB.new File.read(File.join(TEMPLATE_DIR, 'toc.ncx.erb')),
      nil, '<>'

    File.open(File.join(@odir, 'toc.ncx'), 'wb') do |f|
      f.write template.result binding
    end
  end
end
