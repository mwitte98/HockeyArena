class Player < ActiveRecord::Base

  def eql?(other)
  	self.name.eql?(other.name)
  end

  def hash
  	self.name.hash
  end
end
