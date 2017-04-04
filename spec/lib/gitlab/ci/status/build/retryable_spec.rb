require 'spec_helper'

describe Gitlab::Ci::Status::Build::Retryable do
  let(:status) { double('core status') }
  let(:user) { double('user') }

  subject do
    described_class.new(status)
  end

  describe '#text' do
    it 'does not override status text' do
      expect(status).to receive(:text)

      subject.text
    end
  end

  describe '#icon' do
    it 'does not override status icon' do
      expect(status).to receive(:icon)

      subject.icon
    end
  end

  describe '#label' do
    it 'does not override status label' do
      expect(status).to receive(:label)

      subject.label
    end
  end

  describe '#group' do
    it 'does not override status group' do
      expect(status).to receive(:group)

      subject.group
    end
  end

  describe 'action details' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build) }
    let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

    describe '#has_action?' do
      context 'when user is allowed to update build' do
        before { build.project.team << [user, :developer] }

        it { is_expected.to have_action }
      end

      context 'when user is not allowed to update build' do
        it { is_expected.not_to have_action }
      end
    end

    describe '#action_path' do
      it { expect(subject.action_path).to include "#{build.id}/retry" }
    end

    describe '#action_icon' do
      it { expect(subject.action_icon).to eq 'icon_action_retry' }
    end

    describe '#action_title' do
      it { expect(subject.action_title).to eq 'Retry' }
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is retryable' do
      let(:build) do
        create(:ci_build, :success)
      end

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not retryable' do
      let(:build) { create(:ci_build, :running) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
