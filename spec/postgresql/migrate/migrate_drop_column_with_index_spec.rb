# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop column and index' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "idx_dept_name", unique: true
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_emp_dept_no"
          t.index ["emp_no"], name: "idx_dept_emp_emp_no"
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_manager_dept_no"
          t.index ["emp_no"], name: "idx_dept_manager_emp_no"
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id"
        end

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "idx_salaries_emp_no"
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "idx_titles_emp_no"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "idx_dept_name", unique: true
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string "dept_no", limit: 4, null: false
          t.index ["dept_no"], name: "idx_dept_emp_dept_no"
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string "dept_no", limit: 4, null: false
          t.index ["dept_no"], name: "idx_dept_manager_dept_no"
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.index ["emp_no"], name: "idx_employee_clubs_emp_no"
        end

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "idx_salaries_emp_no"
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "idx_titles_emp_no"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate(noop: true)
      expect(subject.dump).to match_ruby actual_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy erbh(<<-ERB)
change_table("dept_emp", bulk: true) do |t|
  t.remove("emp_no")
  t.remove("from_date")
  t.remove("to_date")
end

change_table("dept_manager", bulk: true) do |t|
  t.remove("emp_no")
  t.remove("from_date")
  t.remove("to_date")
end

change_table("employee_clubs", bulk: true) do |t|
  t.remove("club_id")
  t.index(["emp_no"], **#{{ name: 'idx_employee_clubs_emp_no' }})
end

change_table("employees", bulk: true) do |t|
  t.remove("last_name")
  t.remove("hire_date")
end
      ERB
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
