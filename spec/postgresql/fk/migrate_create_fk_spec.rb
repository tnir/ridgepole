# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end
      ERB
    end

    let(:expected_dsl) do
      actual_dsl + <<-RUBY
        add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
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
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        add_foreign_key("child", "parent", **#{{ name: 'child_ibfk_1' }})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create fk when create table' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    let(:sorted_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    before { client(force_drop_table: true).diff('').migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy ''
      delta.migrate
      expect(subject.dump).to match_fuzzy sorted_dsl
    }
  end

  context 'already defined' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    subject { client }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Foreign Key `child(child_ibfk_1)` already defined')
    }
  end

  context 'when create fk without name' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end
      ERB
    end

    let(:expected_dsl) do
      actual_dsl + <<-RUBY
        add_foreign_key "child", "parent"
      RUBY
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
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        add_foreign_key("child", "parent", **{})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'orphan fk' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    subject { client }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Table `child` to create the foreign key is not defined: child_ibfk_1')
    }
  end
end
