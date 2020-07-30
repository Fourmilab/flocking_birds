
ALL = bird.lsl curiosity.lsl damage_bullet.lsl explosion.lsl \
      flight_animation.lsl flight_termination.lsl flocking_birds.lsl \
      laser_cannon.lsl

duh:
	@echo "What'll it be, mate?"

lint:
	for f in $(ALL); \
	do \
		echo $$f: ; \
		lslint $$f ; \
	done
