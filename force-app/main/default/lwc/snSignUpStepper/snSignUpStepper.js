import {LightningElement, api, track} from 'lwc';
import { QUERYING_DATA, VALIDATION, PREPARING, FUNNEL_REQUEST, SYNCED, ACTIVE, COMPLETED, READY, READY_TO_FUNNEL } from "c/snUtils";

class Step {
    status = READY
    constructor(label, lastStep) {
        this.label = label;
        this.lastStep = Boolean(lastStep);
    }

    setActive() {
        this.status = this.status !== COMPLETED ? ACTIVE : COMPLETED;
    }

    setCompleted() {
        this.status = COMPLETED;
    }
}

export default class SnSignUpStepper extends LightningElement {

    @api expanded;
    @api get step() {};

    stepMap = new Map([
        [QUERYING_DATA, new Step(QUERYING_DATA)],
        [VALIDATION, new Step(VALIDATION)],
        [PREPARING, new Step(PREPARING),],
        [FUNNEL_REQUEST, new Step(FUNNEL_REQUEST, true)]
    ]);

    set step(stepName) {
        if (stepName) {
            const STEPS_MAP = this.stepMap;
            switch (stepName) {
                case QUERYING_DATA:
                    STEPS_MAP.get(QUERYING_DATA).setActive();
                    break;
                case VALIDATION:
                    STEPS_MAP.get(QUERYING_DATA).setCompleted();
                    STEPS_MAP.get(VALIDATION).setActive();
                    break;
                case PREPARING:
                    STEPS_MAP.get(VALIDATION).setCompleted();
                    STEPS_MAP.get(PREPARING).setActive();
                    break;
                case READY_TO_FUNNEL:
                case FUNNEL_REQUEST:
                    STEPS_MAP.get(PREPARING).setCompleted();
                    STEPS_MAP.get(FUNNEL_REQUEST).setActive();
                    break;
                case SYNCED:
                    STEPS_MAP.forEach(step => step.setCompleted());
                    break;
                default:
                    break;
            }
            this.resetSteps();
        }
    }

    @track steps = Array.from(this.stepMap.values());

    get sectionClasses() {
        return `expandable ${this.expanded ? 'expanded' : ''}`;
    }

    resetSteps() {
        this.steps = Array.from(this.stepMap.values());
    }
}