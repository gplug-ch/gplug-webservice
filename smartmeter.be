var smartmeter = module()

import strict
import logger
import json

smartmeter.init = def(m)
    # Must be stateful to store data => use class instead of module, which is stateless
    class singleton
        var sm_data
        var history

        def init()
            self.sm_data = map()
            self.history = list()
        end

        def add_to_history(data)
            var pi = data.find('Pi', 0)
            var po = data.find('Po', 0)
            var entry = {
                "in": pi,
                "out": po,
                "timestamp": tasmota.rtc('local')
            }
            if data != nil
                if size(self.history) >= 120
                    self.history.pop(0)  # Remove oldest entry
                end
                self.history.push(entry)
            end
        end

        def every_10_secs()
            # self.sm_data = {'V1': 239, 'P3o': 239, 'Ei': 45982.8, 'rEo': 21155.5, 'rEi': 8579.97, 
            #     'P2o': 167, 'P2i': 0, 'V2': 238, 'rPi': 0, 'Po': 0.632, 'P3i': 0, 
            #     'I2': 1.34, 'pf1': 0.56, 'P1o': 226, 'rPo': 768, 'P1i': 0, 'Pi': 0, 
            #     'SMid': 32942200, 'I3': 1.96, 'Eo': 34485.8, 'V3': 239, 'I1': 2.21}   
            # self.add_to_history(self.sm_data)

            var data = tasmota.read_sensors()
            if data != nil
                self.sm_data = json.load(data).find('z')
                self.add_to_history(self.sm_data)
                logger.logMsg(logger.lDebug, f"Smartmeter data: {self.sm_data}")
            else
                logger.logMsg(logger.lWarn, f"No data. Check smartmeter configuration.")
            end
        end

        def start()
            tasmota.add_cron("*/10 * * * * *", /-> self.every_10_secs(), "every_10_s")
            logger.logMsg(logger.lInfo, "Smartmeter cronjob started")
        end

        def stop()
            tasmota.remove_cron("every_10_s")
            logger.logMsg(logger.lInfo, "Smartmeter cronjob stopped")
        end

        def get_data()
            return self.sm_data
        end

        def get_power_history_from(ts_from)
            if ts_from == nil
                return self.history
            end
            var index = 0
            for entry : self.history
                if ts_from <= entry["timestamp"]
                    break
                end
                index += 1
            end
            return self.history[index ..]
        end

        def deinit()
            self.stop()
        end
    end

    # return a single instance for this class
    return singleton()
end

return smartmeter