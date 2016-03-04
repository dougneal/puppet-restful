Puppet::Type.newtype(:entity) do

  @doc = "Generic configuration item"

  ensurable

  newproperty(:id) do
    desc "The API's identifier for the resource."
  end

  newparam(:name) do
    desc "The name of the item"
    isnamevar
  end

  newproperty(:attributes)

end

