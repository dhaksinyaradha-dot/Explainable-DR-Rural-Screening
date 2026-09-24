function queue = ophthalmologist_queue(patients)

[~, order] = sort([patients.priority], 'descend');

queue = patients(order);

end