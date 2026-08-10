module UsersHelper
  def user_role_name(user)
    %w[admin company student].find { |role| user.has_cached_role?(role) }
  end

  def user_role_label(user)
    {
      "admin" => "Administrador",
      "company" => "Empresa",
      "student" => "Colaborador"
    }.fetch(user_role_name(user), "Sem role")
  end

  def manageable_user?(user)
    return true if Current.user.has_role?(:admin)

    Current.user.has_role?(:company) && Current.user.company.present? && user.has_cached_role?(:student) && user.company == Current.user.company
  end
end
