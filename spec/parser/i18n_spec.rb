require 'abc/parser/i18n'

describe 'translation' do
  it 'works with strings' do
    I18n.t('hello_world').should == "Hello, World!"
  end
  it 'works with symbols' do
    I18n.t(:hello_world).should == "Hello, World!"
  end
  it 'works with scope' do
    I18n.t('abc.hello').should == "Hello, ABC!"
  end
  it 'works with variables' do
    I18n.t('abc.field_type', type:'refnum', identifier:'X').should == "refnum (X:) field"
  end
  it 'can be nested' do
    I18n.t('abc.errors.duplicate', 
           item:I18n.t('abc.field_type', type:'refnum', identifier:'X')
           ).should == "duplicate refnum (X:) field"
  end
end

