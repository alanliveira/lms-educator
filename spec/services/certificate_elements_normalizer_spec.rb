require "rails_helper"

RSpec.describe CertificateElementsNormalizer do
  it "keeps only permitted elements and normalizes collection defaults" do
    elements = described_class.call({
      "signatures" => [{ "id" => "signature-1", "label" => "Responsável" }],
      "unexpected" => { "x" => 99 }
    }.to_json)

    expect(elements.keys).not_to include("unexpected")
    expect(elements["signatures"].first).to include(
      "id" => "signature-1",
      "label" => "Responsável",
      "width" => 24,
      "height" => 10
    )
  end
end
