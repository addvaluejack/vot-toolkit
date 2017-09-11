function [result] = analyze_overlap(experiment, trackers, sequences, varargin)
% analyze_expected_overlap Performs overlap analysis
%
% Performs overlap analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Tags] (cell): An array of tag names that should be used
% instead of sequences.
%
% Output:
% - result (structure): A structure with the following fields
%     - curves: overlap threshold curves
%     - thresholds: corresponding thresholds (x values)
%     - auc: computed AUC values
%

    resolution = 100;
    tags = {};

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'tags'
                tags = varargin{i+1};
            case 'resolution'
                resolution = varargin{i+1} ;
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    print_text('Overlap analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if ~isempty(tags)

        tags = unique(tags); % Remove any potential duplicates.

        selectors = create_tag_selectors(experiment, ...
            experiment_sequences, tags);

    else

        selectors = create_sequence_selectors(experiment, experiment_sequences);

    end;

    result.thresholds = linspace(0, 1, resolution);
    result.curves = zeros(numel(trackers), numel(selectors), resolution);
    result.auc = zeros(numel(trackers), numel(selectors));

    for i = 1:numel(trackers)

        print_text('Tracker %s', trackers{i}.identifier);

        for s = 1:numel(selectors)
            [overlaps, ~] = selectors{s}.aggregate(experiment, trackers{i}, experiment_sequences);
            N = selectors{s}.length(experiment_sequences);
            overlaps(isnan(overlaps)) = 0;

            result.curves(i, s, :) = sum(bsxfun(@(x, y) x > y, overlaps', result.thresholds), 1) ./ N;
            result.auc(i, s) = mean(overlaps);

        end;

    end;

    print_indent(-1);

end
