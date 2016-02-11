class ContractValidationResult
  def initialize(errors)
    @errors = errors || []
  end

  def ok?
    @errors.length == 0
  end

  def errors
    @errors
  end
end
