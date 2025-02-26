@testset "GPS L5" begin
    gpsl5 = GPSL5()
    @test @inferred(Tracking.is_upcoming_integration_new_bit(gpsl5, 0x35, 50)) == true

    @test @inferred(Tracking.is_upcoming_integration_new_bit(gpsl5, 0x35, 5)) == false

    @test @inferred(Tracking.is_upcoming_integration_new_bit(gpsl5, 0x3ca, 10)) == true # 0x3ca == 1111001010

    sampling_frequency = 5e6Hz

    @test @inferred(Tracking.get_default_correlator(gpsl5, sampling_frequency, NumAnts(1))) ==
        EarlyPromptLateCorrelator(gpsl5, sampling_frequency, num_ants = NumAnts(1))
    @test @inferred(Tracking.get_default_correlator(gpsl5, sampling_frequency, NumAnts(3))) ==
        EarlyPromptLateCorrelator(gpsl5, sampling_frequency, num_ants = NumAnts(3))
end
