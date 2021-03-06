# Note: this code was donated by Pat Eyler. Thanks Pat!

require 'test/unit' unless defined? $ZENTEST and $ZENTEST
require 'tagger'
 
class TestTagger < Test::Unit::TestCase
  def setup
    @tt = Tagger.new
  end

  def test_getTags
    assert_equal(["NN"], @tt.getTags("bank"))
    assert_equal(["DT", "NN", "VBZ", "DT", "JJ", "NN", "JJ", "NN"], @tt.getTags("The dog bites the black cat last week."))
    assert_equal(["DT", "NN", "VBD", "NNP", "DT", "NN", "JJ", "NN",
                   nil, "PRP", "MD", "NN", "DT", "NN", "RB", "RB"],
                 @tt.getTags("The bank gave Sam a loan last week. He can bank an airplane really well."))
    assert_equal([],@tt.getTags(""))
    assert_equal(["NN"], @tt.getTags(["bank"]))
    assert_raise(RuntimeError) {@tt.getTags(1)}
  end

  def test_tokenize
    assert_equal(["This", "is", "some", "text"],
                 @tt.tokenize("This is some text."))
  end

end
