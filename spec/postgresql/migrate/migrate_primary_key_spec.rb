# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "employees", id: :serial, force: :cascade do |t|
      end
    ERB
  end

  before do
    subject.diff('').migrate
    subject.diff(actual_dsl).migrate
  end
  subject { client(allow_pk_change: allow_pk_change) }

  context 'when allow_pk_change option is false' do
    let(:allow_pk_change) { false }

    context 'with difference' do
      let(:expected_dsl) do
        erbh(<<-ERB)
          create_table "employees", id: :bigint, force: :cascade do |t|
          end
        ERB
      end

      it {
        expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG)
[WARNING] Primary key definition of `employees` differ but `allow_pk_change` option is false
  from: #{{ id: :serial }}
    to: #{{ id: :bigint }}
        MSG

        delta = subject.diff(expected_dsl)
        expect(delta.differ?).to be_falsey
        delta.migrate
        expect(subject.dump).to match_ruby actual_dsl
      }
    end

    context 'with no difference' do
      let(:actual_dsl) do
        erbh(<<-ERB)
          create_table "employees", id: :serial, force: :cascade do |t|
          end
        ERB
      end
      let(:expected_dsl) { actual_dsl }

      it {
        expect(Ridgepole::Logger.instance).to_not receive(:warn)

        delta = subject.diff(expected_dsl)
        expect(delta.differ?).to be_falsey
      }
    end
  end

  context 'when allow_pk_change option is true' do
    let(:allow_pk_change) { true }
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", id: :serial, force: :cascade do |t|
        end
      ERB
    end
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", force: :cascade do |t|
        end
      ERB
    end

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when allow_pk_change option is true and :id is false' do
    let(:allow_pk_change) { true }
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", id: false, force: :cascade do |t|
        end
      ERB
    end

    it {
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
