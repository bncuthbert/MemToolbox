%SLOTMODEL returns a structure for a two-component mixture model
% capacity K and precision sd. Capacity is the maximum number of independent 
% representations. If the set size is greater than capacity some guesses will
% occur. For example, if participants can store 3 items but have to remember 6,
% participants will guess 50% of the time. Precision is the uncertainty of 
% stored representations, and is assumed to be constant across set size.
%
% In addition to data.errors, requires data.n (the set size for each trial)
%
function model = SlotModel()
  model.name = 'Slot model';
	model.paramNames = {'capacity', 'sd'};
	model.lowerbound = [0 0];     % Lower bounds for the parameters
	model.upperbound = [Inf Inf]; % Upper bounds for the parameters
	model.movestd = [0.25, 0.1];
	model.pdf = @slotpdf;
	model.start = [1, 4;   % capacity, sd
                 4, 15;  % capacity, sd
                 6, 40]; % capacity, sd
               
  model.prior = @(p) (JeffreysPriorForCapacity(p(1)) .* ... % for capacity
                      JeffreysPriorForKappaOfVonMises(deg2k(p(2))));
                    
  % Example of a possible .priorForMC:
  % model.priorForMC = @(p) (lognpdf(p(1),2,1) .* ... % for capacity
  %                            lognpdf(deg2k(p(2)),2,0.5));
  
  % Use our custom modelPlot to make a plot of errors separately for each
  % set size
  model.modelPlot = @model_plot;
  function figHand = model_plot(data, params, varargin)
    figHand = figure();
    if isstruct(params) && isfield(params, 'vals')
      params = MCMCSummarize(params, 'maxPosterior');
    end
    data.condition = data.n;
    [datasets, setSizes] = SplitDataByCondition(data);
    m = StandardMixtureModel();
    for i=1:length(setSizes)
      subplot(1, length(setSizes), i);
      g = (1 - max(0,min(1,params(1)/setSizes(i))));
      curSD = params(2);
      PlotModelFit(m, [g curSD], datasets{i}, 'NewFigure', false, ...
        'ShowNumbers', true, 'ShowAxisLabels', false);
      if i==1
        ylabel('Probability', 'FontSize', 14);
      end
      title(sprintf('Set size %d', setSizes(i)), 'FontSize', 14);
    end
  end     
end

function y = slotpdf(data,capacity,sd)  
  g = (1 - max(0,min(1,capacity./data.n(:))));

  y = (1-g).*vonmisespdf(data.errors(:),0,deg2k(sd)) + ...
        (g).*unifpdf(data.errors(:),-180,180);
   
end
