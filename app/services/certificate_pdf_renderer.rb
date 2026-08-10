require "digest"
require "cgi"
require "prawn"
require "rqrcode"
require "stringio"

class CertificatePdfRenderer
  PAGE_WIDTH = 841.89
  PAGE_HEIGHT = 595.28
  FONT_MAP = {
    "Arial" => "DejaVuSans.ttf",
    "Georgia" => "DejaVuSerif.ttf",
    "Verdana" => "DejaVuSans.ttf",
    "Trebuchet MS" => "DejaVuSans.ttf"
  }.freeze
  FONT_DIRECTORY = "/usr/share/fonts/truetype/dejavu".freeze

  def initialize(certificate, user, verification_url: nil)
    @certificate = certificate
    @user = user
    @course = certificate.course
    @elements = certificate.elements.presence || Certificate::DEFAULT_ELEMENTS
    @verification_url = verification_url
  end

  def render
    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 0).tap do |pdf|
      draw_background(pdf)
      draw_image(pdf, @certificate.verification_seal, element("verification_seal"))
      draw_qr_code(pdf, element("qr_code"))
      draw_text(pdf, verification_code, element("verification_code"))
      draw_description(pdf, element("description"))
      Array(@elements["signatures"]).each { |signature| draw_signature(pdf, signature) }
    end.render
  end

  private

  def draw_background(pdf)
    return unless @certificate.artwork.attached?

    opacity = @elements["background_opacity"].to_f.clamp(0, 1)
    @certificate.artwork.blob.open do |file|
      pdf.transparent(opacity) do
        pdf.image file.path, at: [0, PAGE_HEIGHT], width: PAGE_WIDTH, height: PAGE_HEIGHT
      end
    end
  end

  def draw_image(pdf, attachment, settings)
    return unless attachment&.attached? && settings.is_a?(Hash) && settings.present?

    attachment.blob.open do |file|
      pdf.image file.path, at: top_left(settings), fit: dimensions(settings)
    end
  end

  def draw_qr_code(pdf, settings)
    return unless settings.is_a?(Hash) && settings.present?

    qr = RQRCode::QRCode.new(@verification_url.presence || verification_code)
    pdf.image StringIO.new(qr.as_png(size: 300, border_modules: 0).to_blob),
              at: top_left(settings), fit: dimensions(settings)
  end

  def draw_text(pdf, text, settings)
    return unless settings.is_a?(Hash) && settings.present?

    pdf.fill_color(normalize_color(settings["color"]))
    pdf.font(font_path(settings["font_family"])) do
      pdf.text_box text.to_s,
                   at: top_left(settings),
                   width: dimensions(settings).first,
                   height: dimensions(settings).last,
                   size: settings["font_size"].to_f.clamp(8, 96),
                   align: normalize_align(settings["text_align"]),
                   valign: normalize_valign(settings["vertical_align"]),
                   overflow: :truncate
    end
  end

  def draw_description(pdf, settings)
    return unless settings.is_a?(Hash) && settings.present?

    pdf.fill_color(normalize_color(settings["color"]))
    pdf.font_families.update("CertificateBody" => {
                               normal: font_path(settings["font_family"]),
                               bold: bold_font_path(settings["font_family"])
                             })
    pdf.font("CertificateBody") do
      pdf.formatted_text_box description_parts,
                              at: top_left(settings),
                              width: dimensions(settings).first,
                              height: dimensions(settings).last,
                              size: settings["font_size"].to_f.clamp(8, 96),
                              align: normalize_align(settings["text_align"]),
                              valign: normalize_valign(settings["vertical_align"]),
                              overflow: :shrink_to_fit,
                              min_font_size: 6
    end
  end

  def draw_signature(pdf, signature)
    return unless signature.is_a?(Hash)

    x, y = top_left(signature)
    width, height = dimensions(signature)
    pdf.stroke_color(normalize_color(signature["color"]))
    pdf.stroke_line [x, y - height + 8], [x + width, y - height + 8]
    draw_text(pdf, signature["label"].presence || "Assinatura", signature)
  end

  def element(name)
    @elements[name].is_a?(Hash) ? @elements[name] : {}
  end

  def top_left(settings)
    [PAGE_WIDTH * settings["x"].to_f / 100 - dimensions(settings).first / 2,
     PAGE_HEIGHT - PAGE_HEIGHT * settings["y"].to_f / 100 + dimensions(settings).last / 2]
  end

  def dimensions(settings)
    [PAGE_WIDTH * settings["width"].to_f / 100, PAGE_HEIGHT * settings["height"].to_f / 100]
  end

  def description
    description_parts.map { |part| part[:text] }.join
  end

  def description_parts
    template = @certificate.description.presence || "Certificamos que {{ nome_do_aluno }} concluiu o curso {{ titulo_curso }}."
    fields = description_fields
    CGI.unescapeHTML(template.to_s).split(/(\{\{\s*\w+\s*\}\})/).filter_map do |part|
      next if part.empty?

      match = part.match(/\A\{\{\s*(\w+)\s*\}\}\z/)
      if match
        [{ text: fields.fetch(match[1], match[0]), styles: [:bold] }]
      else
        [{ text: part }]
      end
    end.flatten
  end

  def description_fields
    {
      "nome_do_aluno" => @user.full_name.presence || @user.email_address,
      "data_conclusao" => completion_date,
      "data_conclucao" => completion_date,
      "titulo_curso" => @course.name,
      "carga_horaria" => (@course.workload_hours || @certificate.total_hours).to_i.to_s,
      "nome_da_empresa" => @user.company&.fantasy_name || @user.company&.name.to_s
    }
  end

  def completion_date
    completed_at = CourseCompletionService.new(user: @user, course: @course).completed_at
    I18n.l((completed_at || Time.current).to_date, format: :default)
  end

  def font_path(font_family)
    filename = FONT_MAP.fetch(font_family, "DejaVuSans.ttf")
    path = File.join(FONT_DIRECTORY, filename)
    File.file?(path) ? path : "Helvetica"
  end

  def bold_font_path(font_family)
    normal = font_path(font_family)
    return "Helvetica-Bold" if normal == "Helvetica"

    bold = normal.sub(/\.ttf\z/i, "-Bold.ttf")
    File.file?(bold) ? bold : normal
  end

  def verification_code
    "Código: #{Digest::SHA256.hexdigest("#{@user.id}:#{@course.id}")[0, 12].upcase}"
  end

  def normalize_color(value)
    color = value.to_s
    (color.match?(/\A#[0-9a-fA-F]{6}\z/) ? color : "#111827").delete_prefix("#")
  end

  def normalize_align(value)
    %w[left center right justify].include?(value.to_s) ? value.to_sym : :center
  end

  def normalize_valign(value)
    %w[top center bottom].include?(value.to_s) ? value.to_sym : :center
  end
end
