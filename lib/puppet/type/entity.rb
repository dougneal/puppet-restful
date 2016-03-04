Puppet::Type.newtype(:entity) do

  @doc = "Generic configuration item"

  ensurable

  newparam(:name) do
    desc "The name of the item"
    isnamevar
  end

  newparam(:attributes)

end

