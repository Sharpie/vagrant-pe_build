require 'pe_build/release'

module PEBuild::Release
  twentynineteen_aught_x = newrelease do
    add_release :el, '5'
    add_release :el, '6'
    add_release :el, '7'

    add_release :sles, '11'
    add_release :sles, '12'

    add_release :ubuntu, '14.04'
    add_release :ubuntu, '16.04'
    add_release :ubuntu, '18.04'

    add_release :windows, '2008'
    add_release :windows, '2008R2'
    add_release :windows, '2012'
    add_release :windows, '2012R2'
    add_release :windows, '2016'
    add_release :windows, '7'
    add_release :windows, '8'
    add_release :windows, '8.1'
    add_release :windows, '10'

    set_answer_file :master, File.join(PEBuild.template_dir, 'answers', 'master-2016.2.x.conf.erb')
  end

  @releases['2019.0.0'] = twentynineteen_aught_x
end
