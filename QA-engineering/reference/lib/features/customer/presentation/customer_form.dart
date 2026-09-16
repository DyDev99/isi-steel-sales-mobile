import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/testing/test_keys.dart';
import '../domain/customer.dart';
import 'customer_form_bloc.dart';

class CustomerForm extends StatelessWidget {
  const CustomerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerFormBloc, CustomerFormState>(
      builder: (context, state) {
        final bloc = context.read<CustomerFormBloc>();
        final submitting = state.status == FormStatus.submitting;
        return ListView(
          key: TestKeys.customerForm,
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: TestKeys.customerName,
              decoration: InputDecoration(
                  labelText: 'Customer name',
                  errorText: state.errorFor('name')),
              onChanged: (v) => bloc.add(NameChanged(v)),
            ),
            TextField(
              key: TestKeys.customerPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: 'Phone', errorText: state.errorFor('phone')),
              onChanged: (v) => bloc.add(PhoneChanged(v)),
            ),
            DropdownButtonFormField<CustomerType>(
              key: TestKeys.customerType,
              // ignore: deprecated_member_use
              value: state.type,
              decoration: const InputDecoration(labelText: 'Customer type'),
              items: CustomerType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) bloc.add(TypeChanged(t));
              },
            ),
            TextField(
              key: TestKeys.customerCreditLimit,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Credit limit',
                  errorText: state.errorFor('creditLimit')),
              onChanged: (v) => bloc.add(CreditLimitChanged(v)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: TestKeys.customerSubmit,
              onPressed:
                  submitting ? null : () => bloc.add(const FormSubmitted()),
              child: submitting
                  ? const SizedBox(
                      key: TestKeys.customerSubmitLoading,
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
            if (state.status == FormStatus.success)
              const Padding(
                key: TestKeys.customerSuccess,
                padding: EdgeInsets.only(top: 12),
                child: Text('Customer created successfully'),
              ),
            if (state.status == FormStatus.failure)
              Padding(
                key: TestKeys.customerError,
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.errorMessage ?? 'Error',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
          ],
        );
      },
    );
  }
}
