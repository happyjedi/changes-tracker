RSpec.describe Services::ChangesTracker do
  let(:item) do
    {
      id: 1,
      status: 'enquiry',
      service_type_id: 4
    }
  end
  let(:new_status) { 'prepare_case' }
  let(:company_id) { 2 }

  subject { described_class.new(item) }

  context 'when changes object attributes' do
    describe 'that were stored in object with service initialization' do
      let(:new_service_type_id) { 3 }

      before do
        subject.status = new_status
        subject.service_type_id = new_service_type_id
      end

      let(:result) do
        [
          ['status', [item[:status], new_status]],
          ['service_type_id', [item[:service_type_id], new_service_type_id]]
        ]
      end

      it 'tracks changes' do
        expect(subject.changes).to match_array(result)
      end
    end

    describe 'that were added to object after service initialization' do
      before do
        subject.status = new_status
        subject.company_id = company_id
      end

      let(:result) do
        [
          ['status', [item[:status], new_status]],
          ['company_id', [nil, company_id]]
        ]
      end

      it 'tracks changes' do
        expect(subject.changes).to match_array(result)
      end
    end

    describe '#to_hash' do
      before do
        subject.status = new_status
        subject.company_id = company_id
      end

      let(:result) do
        {
          id: item[:id],
          status: new_status,
          service_type_id: item[:service_type_id],
          company_id: company_id
        }
      end

      it 'returns object attributes as hash' do
        expect(subject.to_hash).to match(result)
      end
    end
  end
end
