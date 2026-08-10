module Users
  class UpdateService
    ROLES = %w[admin company student].freeze

    def initialize(user:, actor:, attributes:)
      @user = user
      @actor = actor
      @attributes = attributes
    end

    def role_change_allowed?
      return true unless requested_role
      return true if requested_role == current_role
      return false unless ROLES.include?(requested_role)

      actor.has_role?(:admin) ? admin_role_change_allowed? : requested_role == 'company'
    end

    def call
      return false unless role_change_allowed?

      user.transaction do
        user.update!(attributes.except(:role))
        update_role! if requested_role && requested_role != current_role
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    attr_reader :user, :actor, :attributes

    def requested_role
      attributes[:role]
    end

    def current_role
      ROLES.find { |role| user.has_role?(role) }
    end

    def admin_role_change_allowed?
      return false if user == actor
      return false if user.company_user&.owner? && requested_role != 'company'

      attributes.dig(:company_user_attributes, :company_id).present?
    end

    def update_role!
      ROLES.each { |role| user.remove_role(role) }
      user.add_role(requested_role)
    end
  end
end
