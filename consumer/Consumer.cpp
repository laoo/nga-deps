// Two fixed-size intervals that cannot both fit where they would like to: the
// smallest model that exercises the part of CP-SAT NGA's Place Step will use,
// and enough to prove that the archive links and runs.

#include "ortools/sat/cp_model.h"

#include <cstdio>

int main()
{
  namespace sat = operations_research::sat;

  sat::CpModelBuilder model;

  auto const first = model.NewIntVar( { 0, 8 } ).WithName( "first" );
  auto const second = model.NewIntVar( { 0, 8 } ).WithName( "second" );

  model.AddNoOverlap( { model.NewFixedSizeIntervalVar( first, 4 ), model.NewFixedSizeIntervalVar( second, 4 ) } );

  auto const response = sat::Solve( model.Build() );

  if ( response.status() != sat::CpSolverStatus::OPTIMAL )
  {
    std::printf( "unexpected status: %d\n", static_cast<int>( response.status() ) );
    return 1;
  }

  auto const firstValue = sat::SolutionIntegerValue( response, first );
  auto const secondValue = sat::SolutionIntegerValue( response, second );

  if ( firstValue + 4 > secondValue && secondValue + 4 > firstValue )
  {
    std::printf( "overlapping solution: %lld and %lld\n", static_cast<long long>( firstValue ),
                 static_cast<long long>( secondValue ) );
    return 1;
  }

  std::printf( "ok: %lld and %lld\n", static_cast<long long>( firstValue ), static_cast<long long>( secondValue ) );
  return 0;
}
