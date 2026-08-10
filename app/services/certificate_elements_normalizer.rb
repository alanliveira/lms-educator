class CertificateElementsNormalizer
  FIXED_ELEMENT_KEYS = %w[verification_code qr_code description verification_seal].freeze
  ALLOWED_KEYS = %w[background_opacity verification_code description verification_seal qr_code signatures element_library signature_library].freeze

  def self.call(raw_elements)
    new(raw_elements).call
  end

  def initialize(raw_elements)
    @raw_elements = raw_elements
  end

  def call
    parsed = JSON.parse(@raw_elements.presence || "{}")
    return {} unless parsed.is_a?(Hash)

    parsed.slice(*ALLOWED_KEYS).tap do |elements|
      elements["background_opacity"] = elements["background_opacity"].to_f.clamp(0, 1)
      elements["signatures"] = normalize_collection(elements["signatures"])
      elements["signature_library"] = normalize_collection(elements["signature_library"])
      elements["element_library"] = normalize_library(elements["element_library"])

      (ALLOWED_KEYS - %w[signatures signature_library element_library background_opacity]).each do |key|
        elements[key] = normalize_element(elements[key]) if elements[key].is_a?(Hash)
      end
    end
  rescue JSON::ParserError
    Certificate::DEFAULT_ELEMENTS.deep_dup
  end

  private

  def normalize_collection(elements)
    Array(elements).filter_map { |element| normalize_collection_element(element) }
  end

  def normalize_library(library)
    return {} unless library.is_a?(Hash)

    library.filter_map do |key, element|
      [key.to_s, normalize_element(element)] if FIXED_ELEMENT_KEYS.include?(key.to_s) && element.is_a?(Hash)
    end.to_h
  end

  def normalize_collection_element(element)
    return unless element.is_a?(Hash)

    normalize_element(
      element,
      id: element["id"].to_s.first(80),
      label: element["label"].to_s.first(80),
      width_fallback: 24
    )
  end

  def normalize_element(element, id: nil, label: nil, width_fallback: 32)
    {
      "x" => clamp_position(element["x"]),
      "y" => clamp_position(element["y"]),
      "width" => clamp_size(element["width"], width_fallback),
      "height" => clamp_size(element["height"], 10),
      "font_family" => normalize_font(element["font_family"]),
      "font_size" => clamp_font_size(element["font_size"]),
      "color" => normalize_color(element["color"]),
      "text_align" => normalize_text_align(element["text_align"]),
      "vertical_align" => normalize_vertical_align(element["vertical_align"])
    }.tap do |normalized|
      normalized["id"] = id if id
      normalized["label"] = label if label
    end
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
end
