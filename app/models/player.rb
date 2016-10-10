class Player < ActiveRecord::Base
  def eql?(other)
    name.eql?(other.name)
  end

  def hash
    name.hash
  end
end
