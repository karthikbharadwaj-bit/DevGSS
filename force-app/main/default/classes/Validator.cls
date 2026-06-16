public with sharing abstract class Validator {
    public final static String SEVERITY_NORMAL = 'NORMAL';
    public final static String SEVERITY_CRITICAL = 'CRITICAL';

    public Validator nextValidator;
    public String severity;
    public Boolean isActive = true;

    public Validator () {
        this.severity = SEVERITY_NORMAL;
    }

    public Validator (String severity) {
        this.severity = severity;
    }

    public void setNextValidator(Validator validator) {
        this.nextValidator = validator;
    }

    public Response validate(Response resp) {
        // Possible need to trigger nextValidator in future
        if (!isActive) {
            return resp;
        }

        if (isFailedValidation()) {
            addErrorMessage(resp);
        }

        if (isBreakingValidation() && isFailedValidation()) {
            return resp;
        }

        if (nextValidator != null) {
            nextValidator.validate(resp);
        }

        return resp;
    }

    public Boolean isBreakingValidation() {
        return severity == SEVERITY_CRITICAL;
    }

    public abstract void addErrorMessage(Response resp);

    public abstract Boolean isFailedValidation();

    public Validator enable(Boolean value) {
        this.isActive = value;
        return this;
    }
    public Validator enable(List<Boolean> values) {
        this.isActive = false;
        for (Boolean val : values) {
            if (val) {
                this.isActive = val;
                break;
            }
        }
        return this;
    }
}