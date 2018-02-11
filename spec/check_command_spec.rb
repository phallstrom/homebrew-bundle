# frozen_string_literal: true

require "spec_helper"

describe Bundle::Commands::Check do
  def do_check
    Bundle::Commands::Check.run
  end

  before do
    Bundle::Commands::Check.reset!
    allow_any_instance_of(IO).to receive(:puts)
  end

  context "when dependencies are satisfied" do
    it "does not raise an error" do
      allow(ARGV).to receive(:value).and_return(nil)
      allow_any_instance_of(Pathname).to receive(:read).and_return("")
      nothing = []
      allow(Bundle::Commands::Check).to receive(:casks_to_install).and_return(nothing)
      allow(Bundle::Commands::Check).to receive(:formulae_to_install).and_return(nothing)
      allow(Bundle::Commands::Check).to receive(:apps_to_install).and_return(nothing)
      allow(Bundle::Commands::Check).to receive(:taps_to_tap).and_return(nothing)
      expect { do_check }.to_not raise_error
    end
  end

  context "no dependencies are specified" do
    it "does not raise an error" do
      allow(ARGV).to receive(:value).and_return(nil)
      allow_any_instance_of(Pathname).to receive(:read).and_return("")
      allow_any_instance_of(Bundle::Dsl).to receive(:entries).and_return([])
      expect { do_check }.to_not raise_error
    end
  end

  context "when casks are not installed" do
    it "raises an error" do
      allow(Bundle).to receive(:cask_installed?).and_return(true)
      allow_any_instance_of(Bundle::CaskDumper).to receive(:casks).and_return([])
      allow(Bundle::BrewInstaller).to receive(:upgradable_formulae).and_return([])
      allow(ARGV).to receive(:include?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:read).and_return("cask 'abc'")
      expect { do_check }.to raise_error(SystemExit)
    end
  end

  context "when formulae are not installed" do
    it "raises an error" do
      allow_any_instance_of(Bundle::CaskDumper).to receive(:casks).and_return([])
      allow(Bundle::BrewInstaller).to receive(:upgradable_formulae).and_return([])
      allow(ARGV).to receive(:include?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'abc'")
      expect { do_check }.to raise_error(SystemExit)
    end
  end

  context "when taps are not tapped" do
    it "raises an error" do
      allow_any_instance_of(Bundle::CaskDumper).to receive(:casks).and_return([])
      allow(Bundle::BrewInstaller).to receive(:upgradable_formulae).and_return([])
      allow(ARGV).to receive(:include?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:read).and_return("tap 'abc/def'")
      expect { do_check }.to raise_error(SystemExit)
    end
  end

  context "when apps are not installed" do
    it "raises an error" do
      allow_any_instance_of(Bundle::MacAppStoreDumper).to receive(:app_ids).and_return([])
      allow(Bundle::BrewInstaller).to receive(:upgradable_formulae).and_return([])
      allow(ARGV).to receive(:include?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:read).and_return("mas 'foo', id: 123")
      expect { do_check }.to raise_error(SystemExit)
    end
  end

  context "when service is not started" do
    before do
      allow_any_instance_of(Bundle::CaskDumper).to receive(:casks).and_return([])
      allow(Bundle::BrewInstaller).to receive(:installed_formulae).and_return(["abc", "def"])
      allow(Bundle::BrewInstaller).to receive(:upgradable_formulae).and_return([])
      allow(ARGV).to receive(:include?).and_return(true)
      allow(Bundle::BrewServices).to receive(:started?).with("abc").and_return(true)
      allow(Bundle::BrewServices).to receive(:started?).with("def").and_return(false)
    end

    it "should not raises error by default" do
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'abc'")
      expect { do_check }.not_to raise_error
    end

    context "restart_service is true" do
      it "raises an error" do
        allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'abc', restart_service: true\nbrew 'def', restart_service: true")
        expect { do_check }.to raise_error(SystemExit)
      end
    end

    context "start_service is true" do
      it "raises an error" do
        allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'abc', start_service: true\nbrew 'def', start_service: true")
        expect { do_check }.to raise_error(SystemExit)
      end
    end
  end

  context "when there are taps to install" do
    before do
      allow(Bundle::Commands::Check).to receive(:any_taps_to_tap?).and_return(true)
    end
    it "does not check for tasks" do
      expect(Bundle::Commands::Check).not_to receive(:any_casks_to_install?)
      expect { do_check }.to raise_error(SystemExit)
    end
    it "does not check for formulae" do
      expect(Bundle::Commands::Check).not_to receive(:any_formulae_to_install?)
      expect { do_check }.to raise_error(SystemExit)
    end
    it "does not check for apps" do
      expect(Bundle::Commands::Check).not_to receive(:any_apps_to_install?)
      expect { do_check }.to raise_error(SystemExit)
    end
  end

  context "when there are formulae to install" do
    before do
      allow(Bundle::Commands::Check).to receive(:any_taps_to_tap?).and_return(false)
      allow(Bundle::Commands::Check).to receive(:any_casks_to_install?).and_return(false)
      allow(Bundle::Commands::Check).to receive(:any_apps_to_install?).and_return(false)
      allow(Bundle::Commands::Check).to receive(:any_formulae_to_install?).and_return(true)
      allow(Bundle::Commands::Check).to receive(:any_formulae_to_start?).and_return(false)
    end
    it "does not start formulae" do
      expect(Bundle::Commands::Check).not_to receive(:any_formulae_to_start?)
      expect { do_check }.to raise_error(SystemExit)
    end
  end

end
