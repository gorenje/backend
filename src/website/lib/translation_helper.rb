class TranslatorHelper
  def initialize(base)
    @base = base + "."
    @paths = []
    @args = []
  end

  def method_missing(name, *args)
    @paths << name
    @args << args
    self
  end

  def _join_paths
    @paths.join(".").tap { @paths = [] }
  end

  def c
    TranslatorHelper.new(@base + _join_paths)
  end

  def t
    if @args.empty?
      I18n.t(@base + _join_paths)
    else
      I18n.t(@base + _join_paths, @args.flatten.reduce(:merge)).tap do
        @args = []
      end
    end
  end
end
