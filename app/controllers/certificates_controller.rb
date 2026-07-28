require Rails.root.join("app/services/certificate_pdf_renderer")

class CertificatesController < ApplicationController
  before_action :require_admin, only: %i[edit update]
  before_action :set_course
  before_action :set_certificate

  def edit; end

  def download
    unless @certificate.persisted?
      redirect_to course_path(@course), alert: "Este curso ainda não possui um certificado configurado."
      return
    end

    unless CourseClassCompletion.course_completed?(Current.user, @course)
      redirect_to course_course_class_path(@course, @course.course_classes.first),
                  alert: "Conclua todas as aulas para baixar o certificado."
      return
    end

    issuance = CourseClassCompletion.issue_certificate_for!(Current.user, @course)
    send_data CertificatePdfRenderer.new(
      @certificate,
      Current.user,
      verification_url: certificate_validation_url(issuance.verification_code)
    ).render,
              filename: "certificado-#{@course.name.parameterize}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def update
    @certificate.assign_attributes(certificate_params)
    @certificate.elements = normalized_elements(params.dig(:certificate, :elements_json))

    if @certificate.save
      redirect_to edit_course_certificate_path(@course), notice: "Certificado atualizado com sucesso."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def require_admin
    return if Current.user&.has_role?(:admin)

    redirect_back_or_to root_path, alert: "Você não tem permissão para editar certificados."
  end

  def set_course
    @course = policy_scope(Course).find(params[:course_id])
  end

  def set_certificate
    @certificate = @course.certificate || @course.build_certificate
  end

  def certificate_params
    params.require(:certificate).permit(:description, :total_hours, :artwork, :verification_seal)
  end

  def normalized_elements(raw_elements)
    parsed = JSON.parse(raw_elements.presence || "{}")
    parsed = {} unless parsed.is_a?(Hash)
    allowed = %w[background_opacity verification_code description verification_seal qr_code signatures element_library signature_library]

    parsed.slice(*allowed).tap do |elements|
      elements["background_opacity"] = elements["background_opacity"].to_f.clamp(0, 1)
      elements["signatures"] = Array(elements["signatures"]).filter_map do |signature|
        normalize_collection_element(signature)
      end
      elements["signature_library"] = Array(elements["signature_library"]).filter_map do |signature|
        normalize_collection_element(signature)
      end
      library = elements["element_library"].is_a?(Hash) ? elements["element_library"] : {}
      elements["element_library"] = library.filter_map do |key, element|
        [key.to_s, normalize_element(element)] if FIXED_ELEMENT_KEYS.include?(key.to_s) && element.is_a?(Hash)
      end.to_h
      allowed.excluding("signatures", "signature_library", "element_library", "background_opacity").each do |key|
        elements[key] = normalize_element(elements[key]) if elements[key].is_a?(Hash)
      end
    end
  rescue JSON::ParserError
    Certificate::DEFAULT_ELEMENTS.deep_dup
  end

  def normalize_collection_element(element)
    return unless element.is_a?(Hash)

    normalized = {
      "id" => element["id"].to_s.first(80),
      "label" => element["label"].to_s.first(80),
      "x" => clamp_position(element["x"]),
      "y" => clamp_position(element["y"]),
      "width" => clamp_size(element["width"], 24),
      "height" => clamp_size(element["height"], 10),
      "font_family" => normalize_font(element["font_family"]),
      "font_size" => clamp_font_size(element["font_size"]),
      "color" => normalize_color(element["color"]),
      "text_align" => normalize_text_align(element["text_align"]),
      "vertical_align" => normalize_vertical_align(element["vertical_align"])
    }
    normalized
  end

  def normalize_element(element)
    {
      "x" => clamp_position(element["x"]),
      "y" => clamp_position(element["y"]),
      "width" => clamp_size(element["width"], 32),
      "height" => clamp_size(element["height"], 10),
      "font_family" => normalize_font(element["font_family"]),
      "font_size" => clamp_font_size(element["font_size"]),
      "color" => normalize_color(element["color"]),
      "text_align" => normalize_text_align(element["text_align"]),
      "vertical_align" => normalize_vertical_align(element["vertical_align"])
    }
  end

  def normalize_font(font)
    %w[Arial Georgia Verdana "Trebuchet MS"].find { |allowed| allowed == font.to_s } || "Arial"
  end

  def normalize_color(color)
    color = color.to_s
    color.match?(/\A#[0-9a-fA-F]{6}\z/) ? color : "#111827"
  end

  def normalize_text_align(value)
    %w[left center right justify].include?(value.to_s) ? value.to_s : "center"
  end

  def normalize_vertical_align(value)
    %w[top center bottom].include?(value.to_s) ? value.to_s : "center"
  end

  def clamp_size(value, fallback)
    value.to_f.clamp(2, 100).round(2).then { |size| value.present? ? size : fallback }
  end

  def clamp_font_size(value)
    value.to_f.clamp(8, 96).round(2).then { |size| value.present? ? size : 16 }
  end

  def clamp_position(value)
    value.to_f.clamp(0, 100).round(2)
  end

  FIXED_ELEMENT_KEYS = %w[verification_code qr_code description verification_seal].freeze
end
