class Skein::Receiver
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident

  # == Instance Methods =====================================================

  def initialize(context = nil, ident = nil)
    @context = context || Skein::Context.default
    @ident = ident || @context.ident(self)
  end
end
