class Certificate < ApplicationRecord
  belongs_to :course
  has_many :certificate_issuances, dependent: :destroy

  has_one_attached :artwork
  has_one_attached :verification_seal

  validates :course, presence: true
  validates :total_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  DEFAULT_ELEMENTS = {
    "background_opacity" => 1,
    "verification_code" => { "x" => 50, "y" => 82, "width" => 32, "height" => 8, "font_family" => "Arial", "font_size" => 16, "color" => "#111827" },
    "qr_code" => { "x" => 88, "y" => 42, "width" => 14, "height" => 14 },
    "description" => { "x" => 50, "y" => 48, "width" => 70, "height" => 14, "font_family" => "Arial", "font_size" => 18, "color" => "#111827", "text_align" => "center", "vertical_align" => "center" },
    "verification_seal" => { "x" => 88, "y" => 14, "width" => 12, "height" => 14 },
    "signatures" => [
      { "id" => "signature-1", "label" => "Assinatura 1", "x" => 28, "y" => 84, "width" => 24, "height" => 10, "font_family" => "Arial", "font_size" => 14, "color" => "#111827" }
    ]
  }.freeze

  after_initialize :set_default_elements, if: :new_record?

  private

  def set_default_elements
    self.elements = DEFAULT_ELEMENTS.deep_dup if elements.blank?
  end
end
