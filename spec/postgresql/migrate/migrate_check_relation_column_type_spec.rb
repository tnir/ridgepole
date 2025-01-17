# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'with warning' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_manager", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        create_table "employees", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "birth_date", null: false
          t.string  "first_name", limit: 14, null: false
          t.string  "last_name", limit: 16, null: false
          t.string  "gender", limit: 1, null: false
          t.date    "hire_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_manager", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.bigint "employee_id"
        end

        create_table "employees", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "birth_date", null: false
          t.string  "first_name", limit: 14, null: false
          t.string  "last_name", limit: 16, null: false
          t.string  "gender", limit: 1, null: false
          t.date    "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(check_relation_type: 'bigserial') }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG)
[WARNING] Relation column type is different.
              employees.id: #{{ type: :integer }}
  dept_manager.employee_id: #{{ type: :bigint }}
      MSG

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'with warning' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_manager", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        create_table "employees", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "birth_date", null: false
          t.string  "first_name", limit: 14, null: false
          t.string  "last_name", limit: 16, null: false
          t.string  "gender", limit: 1, null: false
          t.date    "hire_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_manager", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.integer "employee_id"
        end

        create_table "employees", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "birth_date", null: false
          t.string  "first_name", limit: 14, null: false
          t.string  "last_name", limit: 16, null: false
          t.string  "gender", limit: 1, null: false
          t.date    "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(check_relation_type: 'bigserial') }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
