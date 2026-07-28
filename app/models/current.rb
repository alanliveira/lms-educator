class Current < ActiveSupport::CurrentAttributes
  attribute :session, :company
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true
end
