class ContestsController < ApplicationController

  def index
    @contests = Contest.all
  end

  def show
    @contest = Contest.find(params[:id])
  end

  def new
    @contest = Contest.new(:election_id => params[:election_id], :district_id => params[:district_id])
    render :update do |page|
      editor_id = "#{dom_id(@contest.district)}_contests_new"
      page << "if (!$('#{editor_id}')) {"
      page.insert_html :after, "#{dom_id(@contest.district)}_static", :partial => 'new.html.erb', :locals => { :contest => @contest }
      page << "}"
    end if request.xhr?
  end

  def edit
    @contest = Contest.find(params[:id])
    render :partial => 'edit', :locals => { :contest => @contest } if request.xhr?
  end

  def create
    @contest = Contest.new(params[:contest])
    success = @contest.save
    flash[:notice] = "Contest '" + @contest.display_name + "' has been created." if success
    if request.xhr?
      render :update do |page|
         if success
           page.replace("#{dom_id(@contest.district)}_contests_new", "")
           page.replace "#{dom_id(@contest.district)}_contests", :partial => 'districts/contests', :locals => { :district => @contest.district, :election => @contest.election } 
         else
           page.replace "#{dom_id(@contest)}_contests_new", :partial => 'contests/new.html.erb', :locals => {:contest => @contest }
         end
      end
    elsif success
      redirect_to(@contest)
    else
      render :action => "new"
    end
  end

  # not a standard rails update. Here we handle two cases:
  # - creation of new candidates : return only candidates with errors
  # - update of existing contest's attributes
  # They are mutually exclusive in our ui, and have different display requirements
  def update
    if params[:contest][:display_name]
      update_contest
    else
      update_attributes
    end
  end

  def update_contest
    @contest = Contest.find(params[:id])
    success =  @contest.update_attributes(params[:contest])
    flash[:notice] = "Contest '" + @contest.display_name + "' was updated." if success
    if request.xhr?
      edit_id = "#{dom_id(@contest)}_edit"
      static_id = "#{dom_id(@contest)}_static"
      render :update do |page|
        if success
          page.remove edit_id
          page.replace static_id, :partial => 'static', :locals => { :contest => @contest }
        else
          page.replace edit_id, :partial => 'edit', :locals => { :contest => contest }
        end
      end
    elsif success
      redirect_to @contest
    else
      render :action => 'edit'
    end
  end

  def update_attributes
    raise "No updating of attributes withou AJAX" if !request.xhr?
    @contest = Contest.find(params[:id])
    howMany = @contest.candidates.length;
    success = @contest.update_attributes(params[:contest])
    howMany = @contest.candidates.length - howMany;
    
    error_candidates = @contest.candidates.to_a.find_all { |c| c.invalid? }
    flash[:notice] = pluralize(howMany, 'candidate has', 'candidates have') + " been created." if error_candidates.length == 0
    render :update do |page|
      if error_candidates.length == 0
        page.replace("#{dom_id(@contest)}_candidates_new", "")
        page.replace "#{dom_id(@contest)}_candidates", :partial => 'candidates', :locals => { :contest => @contest } 
      else
        page.replace "#{dom_id(@contest)}_candidates_new", :partial => 'candidates/new.html.erb', :locals => {:model => error_candidates }
      end
    end
  end

  def destroy
    @contest = Contest.find(params[:id])
    display_name = @contest.display_name
    district = @contest.district
    election = @contest.election
    @contest.destroy
    flash[:notice] = "Contest #{display_name} has been deleted." 
    if request.xhr? # coming from editor, replace contest list
      render :update do |page|
        page.replace("#{dom_id(district)}_contests", :partial => 'districts/contests.html.erb', 
          :locals => {:district => district, :election => election })
      end
    else
      redirect_to(contests_url)
    end
  end

end
